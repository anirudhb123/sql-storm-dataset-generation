WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank,
        COALESCE(UPD.Score, 0) AS Upvotes,
        COALESCE(DOWN.Score, 0) AS Downvotes,
        COUNT(c.Id) AS CommentCount,
        CASE 
            WHEN p.ViewCount IS NULL THEN 0
            ELSE p.ViewCount
        END AS TotalViews,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Votes UPD ON p.Id = UPD.PostId AND UPD.VoteTypeId = 2
    LEFT JOIN 
        Votes DOWN ON p.Id = DOWN.PostId AND DOWN.VoteTypeId = 3
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        UNNEST(string_to_array(p.Tags, '<>')) AS t(TagName) ON TRUE
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, UPD.Score, DOWN.Score
),

PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, '; ') AS HistoryTypes,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseVotes,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenVotes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.TotalViews,
    rp.Upvotes,
    rp.Downvotes,
    rp.CommentCount,
    rp.Tags,
    pha.HistoryTypes,
    pha.CloseVotes,
    pha.ReopenVotes,
    CASE 
        WHEN rp.Rank = 1 THEN 'Newest'
        WHEN rp.Upvotes > 0 THEN 'Active'
        ELSE 'Static'
    END AS PostState
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryAggregates pha ON rp.PostId = pha.PostId
WHERE 
    rp.Rank <= 5 OR pha.CloseVotes > 0
ORDER BY 
    rp.Score DESC NULLS LAST, 
    rp.CreationDate DESC;

WITH NULL_BELOW AS (
    SELECT 
        u.DisplayName,
        CASE 
            WHEN u.Location IS NOT NULL THEN u.Location
            ELSE 'Not specified'
        END AS UserLocation,
        COALESCE(u.Reputation, 0) AS Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)

SELECT 
    DisplayName,
    UserLocation,
    Reputation,
    BadgeCount
FROM 
    NULL_BELOW
WHERE 
    BadgeCount > 5
ORDER BY 
    Reputation DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;

