
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        @row_number := IF(@prev_owner = p.OwnerUserId, @row_number + 1, 1) AS RankScore,
        @prev_owner := p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    CROSS JOIN (SELECT @row_number := 0, @prev_owner := NULL) AS vars
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, p.Score, p.ViewCount
),
TopUserPosts AS (
    SELECT 
        OwnerDisplayName,
        COUNT(Id) AS PostsCount,
        SUM(Score) AS TotalScore,
        AVG(ViewCount) AS AvgViewCount
    FROM 
        RankedPosts
    WHERE 
        RankScore <= 5
    GROUP BY 
        OwnerDisplayName
)
SELECT 
    tup.OwnerDisplayName,
    tup.PostsCount,
    tup.TotalScore,
    tup.AvgViewCount
FROM 
    TopUserPosts tup
WHERE 
    tup.PostsCount > 10
ORDER BY 
    tup.TotalScore DESC, tup.PostsCount DESC
LIMIT 10;
