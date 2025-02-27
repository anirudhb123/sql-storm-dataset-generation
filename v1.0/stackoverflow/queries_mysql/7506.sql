
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
        GROUP_CONCAT(DISTINCT pt.Name) AS PostTypes,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', numbers.n), '>', -1)) AS tag
         FROM 
         (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL
          SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL
          SELECT 9 UNION ALL SELECT 10) numbers 
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= numbers.n - 1) AS tag ON tag IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 30 DAY
    GROUP BY 
        p.Id, u.DisplayName, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, p.FavoriteCount
), 
PostVotes AS (
    SELECT 
        PostId, 
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
), 
TopPosts AS (
    SELECT 
        rp.*, 
        pv.UpVotes,
        pv.DownVotes,
        pv.TotalVotes,
        RANK() OVER (ORDER BY rp.Score DESC, rp.ViewCount DESC) AS Rank
    FROM 
        RecentPosts rp
    LEFT JOIN 
        PostVotes pv ON rp.PostId = pv.PostId
)
SELECT 
    PostId, 
    Title, 
    OwnerDisplayName, 
    CreationDate, 
    Score, 
    ViewCount,
    AnswerCount, 
    CommentCount, 
    FavoriteCount, 
    PostTypes, 
    Tags, 
    UpVotes, 
    DownVotes, 
    TotalVotes,
    Rank
FROM 
    TopPosts
WHERE 
    Rank <= 10
ORDER BY 
    Rank;
