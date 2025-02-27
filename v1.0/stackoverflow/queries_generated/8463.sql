WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- Posts from the last year
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.PostTypeId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.VoteCount,
        pt.Name AS PostTypeName,
        ROW_NUMBER() OVER (ORDER BY rp.Score DESC, rp.ViewCount DESC) AS OverallRank
    FROM 
        RankedPosts rp
    JOIN 
        PostTypes pt ON rp.PostTypeId = pt.Id
    WHERE 
        rp.Rank <= 5 -- Top 5 posts per type
)
SELECT 
    t.PostId,
    t.Title,
    t.Score,
    t.ViewCount,
    t.CommentCount,
    t.VoteCount,
    t.PostTypeName
FROM 
    TopPosts t
WHERE 
    t.OverallRank <= 25 -- Get overall top 25 posts across all types
ORDER BY 
    t.Score DESC;
