
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM Posts p
    OUTER APPLY STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') AS t(TagName)
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.AnswerCount, p.PostTypeId
),

PostStatistics AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        AnswerCount,
        Tags,
        Rank
    FROM RankedPosts
    WHERE Rank <= 10 
),

UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.AnswerCount,
    ps.Tags,
    ue.UserId,
    ue.DisplayName,
    ue.VoteCount,
    ue.UpVotes,
    ue.DownVotes
FROM PostStatistics ps
JOIN UserEngagement ue ON ps.PostId = ue.UserId
ORDER BY ps.CreationDate DESC, ps.Score DESC;
