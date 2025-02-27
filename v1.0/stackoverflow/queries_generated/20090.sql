WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS Owner,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '3 months'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Considering Closed and Reopened
    GROUP BY 
        ph.PostId
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(v.VoteCount, 0)) AS TotalVotes,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id
),
PostAnalytics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        COALESCE(cp.LastClosedDate, 'No closure') AS LastClosed,
        COALESCE(cp.CloseReasons, 'N/A') AS CloseReasons,
        us.TotalPosts AS AuthorTotalPosts,
        us.TotalVotes AS AuthorTotalVotes,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
    JOIN 
        UserStatistics us ON us.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
    WHERE 
        rp.Rank <= 5 -- Top 5 highest scored posts per type
)
SELECT 
    pa.Title,
    pa.Score,
    pa.ViewCount,
    pa.LastClosed,
    pa.CloseReasons,
    pa.AuthorTotalPosts,
    pa.AuthorTotalVotes,
    pa.GoldBadges,
    pa.SilverBadges,
    pa.BronzeBadges,
    CASE 
        WHEN pa.LastClosed IS NOT NULL AND pa.LastClosed <> 'No closure' THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    TRIM(UPPER(pa.Title)) AS NormalizedTitle, -- Example of string manipulation
    NULLIF(pa.CloseReasons, 'N/A') AS ValidCloseReasons -- Handling possible NULL results
FROM 
    PostAnalytics pa
ORDER BY 
    pa.Score DESC NULLS LAST;
