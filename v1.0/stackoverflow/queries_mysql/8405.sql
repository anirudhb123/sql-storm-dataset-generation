
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT DISTINCT tag FROM (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1)) AS tag FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1) tags) tag ON tag IS NOT NULL
    LEFT JOIN 
        Tags t ON tag = t.TagName
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR 
        AND p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, U.DisplayName
), 
PostStatistics AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName,
        UpVotes,
        DownVotes,
        CommentCount,
        Tags,
        @rank := IF(@prevScore = Score, @rank, @rank + 1) AS Rank,
        @prevScore := Score
    FROM 
        RankedPosts, (SELECT @rank := 0, @prevScore := NULL) AS vars
    ORDER BY 
        Score DESC, ViewCount DESC
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.OwnerDisplayName,
    PS.UpVotes,
    PS.DownVotes,
    PS.CommentCount,
    PS.Tags
FROM 
    PostStatistics PS
WHERE 
    PS.Rank <= 10
ORDER BY 
    PS.Rank;
