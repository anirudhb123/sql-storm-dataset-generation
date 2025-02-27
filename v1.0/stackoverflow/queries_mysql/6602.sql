
WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        t.TagName
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT TagName FROM (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '<>', n.n), '<>', -1) AS TagName
          FROM Posts p JOIN (SELECT a.N + 1 AS n FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a) n ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '<>', '')) >= n.n - 1) AS t) AS t ON true
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, t.TagName
),
RankedPosts AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY TagName ORDER BY VoteCount DESC, UpVotes DESC) AS Rank
    FROM 
        PostStatistics
)
SELECT 
    PostId,
    Title,
    CreationDate,
    CommentCount,
    VoteCount,
    UpVotes,
    DownVotes,
    TagName
FROM 
    RankedPosts
WHERE 
    Rank <= 10
ORDER BY 
    TagName, Rank;
