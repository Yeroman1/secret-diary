import 'package:flutter/material.dart';

enum PhosphorIconsStyle { regular, bold, fill }

class PhosphorIcons {
  PhosphorIcons._();

  static IconData bookOpen([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) =>
      style == PhosphorIconsStyle.fill ? Icons.menu_book_rounded : Icons.menu_book_outlined;

  static IconData magnifyingGlass([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) =>
      style == PhosphorIconsStyle.bold ? Icons.search_rounded : Icons.search_outlined;

  static IconData folderStar([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) =>
      style == PhosphorIconsStyle.fill ? Icons.folder_special_rounded : Icons.folder_special_outlined;

  static IconData gear([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) =>
      style == PhosphorIconsStyle.fill ? Icons.settings_rounded : Icons.settings_outlined;

  static IconData plus([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) => Icons.add_rounded;

  static IconData lockKey([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) =>
      style == PhosphorIconsStyle.bold ? Icons.lock_rounded : Icons.lock_outline_rounded;

  static const IconData lockKeyBold = Icons.lock_rounded;

  static IconData lockKeyOpen([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) =>
      style == PhosphorIconsStyle.bold ? Icons.lock_open_rounded : Icons.lock_open_outlined;

  static IconData star([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) =>
      style == PhosphorIconsStyle.fill ? Icons.star_rounded : Icons.star_outline_rounded;

  static const IconData starFill = Icons.star_rounded;

  static IconData fingerprint([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) => Icons.fingerprint_rounded;

  static IconData backspace([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) => Icons.backspace_outlined;

  static IconData bookBookmark([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) => Icons.bookmark_border_rounded;

  static IconData textB([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) => Icons.format_bold_rounded;

  static IconData textItalic([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) => Icons.format_italic_rounded;

  static IconData textUnderline([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) => Icons.format_underlined_rounded;

  static IconData textStrikethrough([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) => Icons.strikethrough_s_rounded;

  static IconData textHOne([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) => Icons.title_rounded;

  static IconData textHTwo([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) => Icons.text_fields_rounded;

  static IconData textHThree([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) => Icons.format_size_rounded;

  static IconData listBullets([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) => Icons.format_list_bulleted_rounded;

  static IconData listNumbers([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) => Icons.format_list_numbered_rounded;

  static IconData quotes([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) => Icons.format_quote_rounded;

  static IconData checkSquare([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) => Icons.check_box_outlined;

  static IconData code([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) => Icons.code_rounded;

  static IconData minus([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) => Icons.horizontal_rule_rounded;

  static IconData caretLeft([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) => Icons.arrow_back_ios_new_rounded;

  static IconData feather([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) => Icons.edit_note_rounded;

  static IconData pencilSimple([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) => Icons.edit_rounded;

  static IconData eye([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) => Icons.remove_red_eye_outlined;

  static IconData caretDown([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) => Icons.keyboard_arrow_down_rounded;

  static IconData chartBar([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) => Icons.bar_chart_rounded;

  static IconData x([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) => Icons.close_rounded;

  static IconData trash([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) => Icons.delete_outline_rounded;

  static IconData tag([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) => Icons.label_outline_rounded;

  static IconData heartbeat([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) => Icons.favorite_rounded;

  static IconData check([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) => Icons.check_rounded;

  static IconData export([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) => Icons.upload_rounded;

  static IconData shareNetwork([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) => Icons.share_rounded;

  static IconData downloadSimple([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) => Icons.download_rounded;

  static IconData timer([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) => Icons.timer_outlined;

  static IconData handTap([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) => Icons.vibration_rounded;

  static IconData maskHappy([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) => Icons.theater_comedy_rounded;

  static IconData checkCircle([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) =>
      style == PhosphorIconsStyle.fill ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded;

  static IconData circle([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) => Icons.radio_button_unchecked_rounded;

  static IconData palette([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) => Icons.palette_outlined;

  static IconData caretRight([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) => Icons.chevron_right_rounded;

  static IconData floppyDisk([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) => Icons.save_outlined;
}
