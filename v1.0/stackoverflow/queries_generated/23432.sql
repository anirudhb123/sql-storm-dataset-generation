WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        COALESCE(c.CommentCount, 0) AS TotalComments,
        COALESCE(v.UpVotes, 0) - COALESCE(v.DownVotes, 0) AS NetVotes,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM
        Posts p
    LEFT JOIN (
        SELECT
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN 
        STRING_TO_ARRAY(substring(p.Tags, 2, length(p.Tags)-2), '><') AS t ON p.Id = t.Id
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
ClosedPosts AS (
    SELECT
        ph.PostId,
        ph.CreationDate,
        COUNT(*) AS CloseCount,
        MAX(ph.CreationDate) AS LastClosed
    FROM PostHistory ph
    WHERE
        ph.PostHistoryTypeId = 10
    GROUP BY
        ph.PostId, ph.CreationDate
),
UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
FinalOutput AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.TotalComments,
        rp.NetVotes,
        rp.Tags,
        cp.CloseCount,
        cp.LastClosed,
        us.DisplayName AS MostActiveUser,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges,
        us.TotalBounties
    FROM RankedPosts rp
    LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
    LEFT JOIN (
        SELECT
            UserId, 
            DisplayName,
            ROW_NUMBER() OVER (ORDER BY SUM(v.BountyAmount) DESC) AS UserRank
        FROM Votes v
        INNER JOIN Users u ON v.UserId = u.Id
        GROUP BY u.Id, u.DisplayName
    ) us ON us.UserRank = 1
)
SELECT 
    *
FROM 
    FinalOutput
WHERE 
    CloseCount IS NULL OR CloseCount > 2
ORDER BY 
    Score DESC NULLS LAST, CreationDate ASC;


This query structure showcases various SQL concepts, including Common Table Expressions (CTEs), window functions, and logical predicates. It also handles NULL values and aggregates, while focusing on performance-sensitive tasks, such as ranking and inner joins with correlated subqueries, producing a highly structured and informative output.
