#include <linux/limits.h>
#define _GNU_SOURCE

#include "enum_generator.h"

#include <dirent.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>


[[nodiscard]]
static inline bool streq(char const *const s1, char const *const s2)
{
   return strcmp(s1, s2) == 0;
}

[[nodiscard]]
static inline char const *file_get_extension(char const *const filename)
{
   char const *ext = strchr(filename, '.');
   return ext == nullptr ? "" : ext;
}

[[nodiscard]]
static inline long file_get_size(FILE *const fp)
{
   fseek(fp, 0L, SEEK_END);
   long const fileSize = ftell(fp);
   fseek(fp, 0L, SEEK_SET);

   return fileSize;
}


static void generate_enum_file(char const *const filename)
{
   FILE *const fp = fopen(filename, "r");
   if (fp == nullptr)
   {
      fprintf(stderr, "ERR - Impossible to open the config file.\n");
      return;
   }

   long const fileSize = file_get_size(fp);
   if (fileSize == 0)
   {
      fprintf(stderr, "ERR - File size = 0. Either empty or failed to read.\n");
      return;
   }

   char *const fileContent = malloc(fileSize + 1);
   if (fileContent == nullptr)
   {
      fprintf(stderr, "ERR - Failed to allocate %lu bytes.", fileSize + 1);
      fclose(fp);
      return;
   }

   fread(fileContent, sizeof(char), fileSize, fp);
   fclose(fp);

   fileContent[fileSize] = '\0';

   printf("=== ENUM CONFIG FILE ===\n");
   printf("Config File: %s\n", filename);
   printf("Content:\n%s", fileContent);

   // TODO: Parse the configuration file + generate the enum file.

   free(fileContent);
}


static void start_generator_from_directory(char const *dirpath, bool const recursive)
{
   if (dirpath == nullptr)
      return;

   DIR *const dirStream = opendir(dirpath);
   if (dirStream == nullptr)
      return;

   struct dirent const *dirInfo = nullptr;
   while ((dirInfo = readdir(dirStream)) != nullptr)
   {
      if (streq(dirInfo->d_name, ".") || streq(dirInfo->d_name, ".."))
         continue;

      if (dirInfo->d_type == DT_DIR && recursive)
      {
         if (chdir(dirInfo->d_name) != 0)
            continue;

         start_generator_from_directory(".", true);
         chdir("..");
         continue;
      }

      char const *fileExt = file_get_extension(dirInfo->d_name);
      if (streq(fileExt, ENUMGEN_FILE_EXTENSION))
      {
         generate_enum_file(dirInfo->d_name);
      }
   }

   closedir( dirStream );
}


int main(int const argc, char **const argv)
{
   for (int idx = 1; idx < argc; ++idx)
   {
      char dirFullpath[PATH_MAX];

      if (realpath(argv[idx], dirFullpath) == nullptr)
      {
         fprintf(stderr, "Impossible to retrieve the directory fullpath of '%s'\n", argv[idx]);
         continue;
      }

      if (chdir(dirFullpath) != 0)
      {
         fprintf(stderr, "Impossible to set root directory %s\n", dirFullpath);
         continue;
      }

      printf("Starting directory: %s\n", dirFullpath);
      start_generator_from_directory(".", true);
   }

   return 0;
}
