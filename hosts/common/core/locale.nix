{ lib, ... }:
{
  i18n.defaultLocale = lib.mkDefault "nl_NL.UTF-8";
  time.timeZone = lib.mkDefault "Europe/Amsterdam";
}
