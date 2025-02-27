WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Filtering to consider only Questions
),
RecentPosts AS (
    SELECT 
        PostId, 
        Title, 
        ViewCount, 
        CreationDate, 
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        RankByViews <= 3 -- Getting top 3 posts by view count per tag
),
StringAggregatedTags AS (
    SELECT
        Tags AS AggregatedTags,
        STRING_AGG(DISTINCT Title, ', ') AS RelatedPostTitles
    FROM 
        Posts
    GROUP BY 
        Tags
),
UserVoteCounts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(v.PostId) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.CreationDate,
    rp.OwnerDisplayName,
    st.AggregatedTags,
    uv.TotalVotes
FROM 
    RecentPosts rp
JOIN 
    StringAggregatedTags st ON st.AggregatedTags LIKE CONCAT('%', (SELECT Tags FROM Posts WHERE Id = rp.PostId), '%')
JOIN 
    UserVoteCounts uv ON uv.OwnerUserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
ORDER BY 
    rp.CreationDate DESC;
