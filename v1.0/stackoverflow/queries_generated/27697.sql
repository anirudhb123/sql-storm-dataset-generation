WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        COALESCE(SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN a.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS PostTypeRank
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.PostTypeId = 1 -- Filter for questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopRankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostsCount
    FROM 
        Users u
    JOIN 
        Posts p ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Tags,
    rp.CommentCount,
    rp.AnswerCount,
    u.UserId,
    u.DisplayName AS PostOwner,
    u.TotalScore AS OwnerTotalScore,
    u.PostsCount AS OwnerPostsCount,
    rp.UserPostRank,
    rp.PostTypeRank
FROM 
    RankedPosts rp
JOIN 
    TopRankedUsers u ON rp.UserPostRank = 1 AND rp.UserPostRank = u.PostsCount
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
