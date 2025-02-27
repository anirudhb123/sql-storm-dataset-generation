WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><') ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Only consider Questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5  -- Top 5 posts per tag
),
PostVoteCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)  -- Only Upvotes and Downvotes
    GROUP BY 
        p.Id
),
FinalResults AS (
    SELECT 
        trp.Title,
        trp.OwnerDisplayName,
        trp.CreationDate,
        trp.ViewCount,
        trp.Score,
        trp.Tags,
        pvc.VoteCount
    FROM 
        TopRankedPosts trp
    JOIN 
        PostVoteCounts pvc ON trp.PostId = pvc.PostId
)
SELECT 
    Title,
    OwnerDisplayName,
    CreationDate,
    ViewCount,
    Score,
    Tags,
    VoteCount,
    'Popular Tag: ' || ANY(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS PopularTag
FROM 
    FinalResults
ORDER BY 
    VoteCount DESC, 
    Score DESC
LIMIT 10;  -- Limit to top 10 posts based on vote count and score
