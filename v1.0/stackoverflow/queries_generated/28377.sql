WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankWithinType
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01'  -- Only consider posts created this year
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.Body, p.Tags, p.CreationDate, p.ViewCount
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.ViewCount,
        rp.CommentCount,
        rp.VoteCount,
        rp.RankWithinType
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankWithinType <= 5  -- Get top 5 posts within each type
),
PostTags AS (
    SELECT 
        tp.PostId,
        STRING_AGG(t.TagName, ',') AS AllTags
    FROM 
        TopPosts tp
    LEFT JOIN 
        (SELECT Id, TagName FROM Tags) t ON t.Id = ANY(string_to_array(tp.Tags, ',')::int[])
    GROUP BY 
        tp.PostId
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.OwnerDisplayName,
    pp.CreationDate,
    pp.ViewCount,
    pp.CommentCount,
    pp.VoteCount,
    pt.AllTags,
    EXTRACT(EPOCH FROM now() - pp.CreationDate) AS AgeInSeconds
FROM 
    TopPosts pp
JOIN 
    PostTags pt ON pp.PostId = pt.PostId
ORDER BY 
    pp.ViewCount DESC;
