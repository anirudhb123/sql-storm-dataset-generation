WITH TagStats AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName,
        COUNT(*) AS PostCount,
        SUM(Case When PostTypeId = 1 Then 1 Else 0 End) AS QuestionCount,
        SUM(Case When PostTypeId = 2 Then 1 Else 0 End) AS AnswerCount,
        SUM(ViewCount) AS TotalViews,
        SUM(Case When AcceptedAnswerId IS NOT NULL Then 1 Else 0 End) AS AcceptedAnswerCount
    FROM 
        Posts
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        TagName
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COUNT(DISTINCT c.Id) AS CommentsCount,
        SUM(v.VoteTypeId = 2) AS UpVotesCount,
        SUM(v.VoteTypeId = 3) AS DownVotesCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistorySummary AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        COUNT(ph.Id) AS EditCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS ClosureCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON ph.PostId = p.Id
    GROUP BY 
        p.Id, p.Title, p.CreationDate
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.TotalViews,
    ts.AcceptedAnswerCount,
    ue.UserId,
    ue.DisplayName,
    ue.PostsCount,
    ue.CommentsCount,
    ue.UpVotesCount,
    ue.DownVotesCount,
    phs.Id AS PostId,
    phs.Title AS PostTitle,
    phs.CreationDate AS PostCreationDate,
    phs.EditCount,
    phs.ClosureCount
FROM 
    TagStats ts
JOIN 
    UserEngagement ue ON ts.QuestionCount > 0
JOIN 
    PostHistorySummary phs ON phs.EditCount > 0
ORDER BY 
    ts.PostCount DESC, 
    ue.PostsCount DESC, 
    phs.EditCount DESC;
