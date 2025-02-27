WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.Tags, p.Score, p.CreationDate, u.DisplayName
),
FilteredTags AS (
    SELECT 
        unnest(string_to_array(Tags, ',')) AS TagName
    FROM 
        Posts
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        unnest(string_to_array(Tags, ',')) 
),
RecentVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 WHEN vt.Name = 'DownMod' THEN -1 ELSE 0 END) AS VoteScore
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Tags,
    rp.Score,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.Rank,
    rt.TagName,
    COALESCE(rv.VoteScore, 0) AS VoteScore,
    rp.CommentCount
FROM 
    RankedPosts rp
JOIN 
    FilteredTags rt ON rt.TagName = ANY(string_to_array(rp.Tags, ','))
LEFT JOIN 
    RecentVotes rv ON rp.PostId = rv.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
