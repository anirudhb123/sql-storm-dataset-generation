
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        TRIM(tag) AS TagName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1)) tag
         FROM 
         (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL 
          SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
         WHERE 
         CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1) AS tag 
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 30 DAY
    ORDER BY 
        p.CreationDate DESC
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
PostAnalytics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.FavoriteCount,
        vs.UpVotes,
        vs.DownVotes,
        rp.TagName
    FROM 
        RecentPosts rp
    LEFT JOIN 
        VoteSummary vs ON rp.PostId = vs.PostId
)
SELECT 
    pa.OwnerDisplayName,
    pa.Title,
    pa.CreationDate,
    pa.Score,
    pa.ViewCount,
    pa.AnswerCount,
    pa.CommentCount,
    pa.FavoriteCount,
    pa.UpVotes,
    pa.DownVotes,
    GROUP_CONCAT(DISTINCT pa.TagName ORDER BY pa.TagName SEPARATOR ', ') AS Tags
FROM 
    PostAnalytics pa
GROUP BY 
    pa.OwnerDisplayName, pa.Title, pa.CreationDate, pa.Score, pa.ViewCount, pa.AnswerCount, pa.CommentCount, pa.FavoriteCount, pa.UpVotes, pa.DownVotes
ORDER BY 
    pa.CreationDate DESC
LIMIT 100;
