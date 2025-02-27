
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        COALESCE((
            SELECT COUNT(*) 
            FROM Comments c 
            WHERE c.PostId = p.Id
        ), 0) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    CROSS APPLY 
        STRING_SPLIT(p.Tags, '<>') AS tag
    JOIN 
        Tags t ON t.TagName = tag.value
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, u.DisplayName
),
VoteSummary AS (
    SELECT 
        PostId, 
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
BadgeSummary AS (
    SELECT 
        UserId, 
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
),
FinalResults AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.Score,
        pd.ViewCount,
        pd.AnswerCount,
        pd.CommentCount,
        pd.OwnerDisplayName,
        COALESCE(vs.UpVotes, 0) AS UpVotes,
        COALESCE(vs.DownVotes, 0) AS DownVotes,
        pd.Tags,
        bd.BadgeCount
    FROM 
        PostDetails pd
    LEFT JOIN 
        VoteSummary vs ON pd.PostId = vs.PostId
    LEFT JOIN 
        BadgeSummary bd ON pd.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = bd.UserId)
)
SELECT TOP 100
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    AnswerCount,
    CommentCount,
    OwnerDisplayName,
    UpVotes,
    DownVotes,
    Tags,
    BadgeCount
FROM 
    FinalResults
ORDER BY 
    Score DESC, ViewCount DESC;
