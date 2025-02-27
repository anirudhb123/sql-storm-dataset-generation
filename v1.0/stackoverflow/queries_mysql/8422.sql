
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
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '<>', n.n), '<>', -1) AS TagName
         FROM Posts p
         JOIN (SELECT a.N + b.N * 10 + 1 n
               FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
                    (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b) n
         WHERE n.n <= 1 + (LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '<>', ''))) ) AS tag ON true
    JOIN 
        Tags t ON t.TagName = tag.TagName
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, u.DisplayName
),
VoteSummary AS (
    SELECT 
        PostId, 
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
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
SELECT 
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
    Score DESC, ViewCount DESC
LIMIT 100;
