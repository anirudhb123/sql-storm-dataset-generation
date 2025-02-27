WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.ViewCount, 
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.PostTypeId
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Score, 
        rp.ViewCount, 
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
)

SELECT 
    tp.PostId, 
    tp.Title, 
    tp.Score, 
    tp.ViewCount, 
    tp.CommentCount, 
    COALESCE((
        SELECT STRING_AGG(u.DisplayName, ', ') 
        FROM Users u 
        JOIN Votes v ON v.PostId = tp.PostId 
        WHERE v.VoteTypeId = 2
    ), 'No votes yet') AS TopVoterNames,
    (
        SELECT 
            JSON_AGG(b.Name) 
        FROM 
            Badges b 
        WHERE 
            b.UserId IN (
                SELECT DISTINCT u.Id 
                FROM Users u 
                JOIN Votes v ON v.UserId = u.Id 
                WHERE v.PostId = tp.PostId
            )
    ) AS AwardedBadges
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC;
