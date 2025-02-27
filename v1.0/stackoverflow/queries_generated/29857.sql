WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.PostTypeId = 1
),
TagStatistics AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        RankedPosts
    GROUP BY 
        TagName
),
UserEngagement AS (
    SELECT 
        p.OwnerUserId,
        SUM(c.Score) AS TotalCommentScore,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS TotalUpvotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS TotalDownvotes,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    ua.TotalCommentScore,
    ua.TotalUpvotes,
    ua.TotalDownvotes,
    ua.TotalComments,
    ts.TagName,
    ts.TagCount
FROM 
    RankedPosts rp
JOIN 
    UserEngagement ua ON rp.OwnerUserId = ua.OwnerUserId
LEFT JOIN 
    TagStatistics ts ON ts.TagName = ANY(string_to_array(substring(rp.Tags, 2, length(rp.Tags) - 2), '><'))
WHERE 
    rp.PostRank <= 5
ORDER BY 
    ua.TotalComments DESC, rp.Score DESC;
