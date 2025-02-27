WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate) AS Rank,
        ARRAY_AGG(DISTINCT tag.TagName) AS Tags
    FROM 
        Posts p 
    LEFT JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tag(TagName)
    WHERE 
        p.PostTypeId IN (1, 2) -- Considering only Questions and Answers
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
FilteredPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.ViewCount, 
        rp.Score, 
        rp.Rank,
        rp.Tags,
        COALESCE(b.Reputation, 0) AS UserReputation
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON u.Id = (
            SELECT OwnerUserId 
            FROM Posts 
            WHERE Id = rp.PostId 
            LIMIT 1
        )
    LEFT JOIN 
        Badges b ON b.UserId = u.Id AND b.Class = 1 -- Gold badges
    WHERE 
        rp.Rank <= 10 -- Get top 10 posts per type
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId
),
FinalOutput AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.CreationDate,
        fp.ViewCount,
        fp.Score,
        fp.Rank,
        fp.Tags,
        fp.UserReputation,
        COALESCE(cph.CloseCount, 0) AS CloseCount
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        ClosedPostHistory cph ON cph.PostId = fp.PostId
)
SELECT
    PostId,
    Title,
    CreationDate,
    ViewCount,
    Score,
    Tags,
    UserReputation,
    CloseCount,
    CASE 
        WHEN CloseCount > 0 THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus,
    CASE 
        WHEN UserReputation IS NULL THEN 
            'User data not available' 
        WHEN UserReputation < 100 THEN 
            'New Contributor'
        ELSE 
            'Established Contributor'
    END AS ContributorStatus
FROM 
    FinalOutput
WHERE 
    UserReputation > 50 OR CloseCount < 1
ORDER BY 
    Score DESC, CreationDate DESC
LIMIT 50;

