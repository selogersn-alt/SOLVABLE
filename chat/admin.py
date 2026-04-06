from django.contrib import admin
from .models import Conversation, Message

class MessageInline(admin.TabularInline):
    model = Message
    extra = 1

@admin.register(Conversation)
class ConversationAdmin(admin.ModelAdmin):
    list_display = ('id', 'topic', 'show_participants', 'updated_at')
    list_filter = ('topic', 'created_at', 'updated_at')
    search_fields = ('id', 'participants__phone_number', 'participants__first_name')
    filter_horizontal = ('participants',)
    inlines = [MessageInline]
    ordering = ('-updated_at',)

    def show_participants(self, obj):
        return ", ".join([str(p.phone_number) for p in obj.participants.all()])
    show_participants.short_description = "Participants"

@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):
    list_display = ('sender', 'conversation', 'is_read', 'created_at')
    list_filter = ('is_read', 'created_at')
    search_fields = ('content', 'sender__email')
