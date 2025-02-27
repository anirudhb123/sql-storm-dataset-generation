WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        SUM(v.BountyAmount) OVER (PARTITION BY p.Id) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)
    WHERE 
        p.Score > 0
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        COALESCE(rp.TotalBounty, 0) AS TotalBounty,
        U.Reputation,
        U.DisplayName,
        CASE 
            WHEN U.Location IS NULL THEN 'Location not specified'
            ELSE U.Location
        END AS UserLocation,
        CASE 
            WHEN rp.Rank = 1 THEN 'Most Recent Post'
            ELSE 'Older Post'
        END AS PostStatus
    FROM 
        RankedPosts rp
    JOIN 
        Users U ON rp.OwnerUserId = U.Id
    WHERE 
        U.Reputation >= (SELECT AVG(Reputation) FROM Users WHERE Reputation IS NOT NULL)
        AND rp.TotalBounty > (SELECT AVG(BountyAmount) FROM Votes WHERE VoteTypeId IN (8) GROUP BY PostId HAVING PostId IS NOT NULL)
),
PostDetails AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.TotalBounty,
        fp.DisplayName,
        fp.UserLocation,
        fp.PostStatus,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN ph.Comment IS NOT NULL THEN 1 ELSE 0 END) AS EditTagCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        Comments c ON fp.PostId = c.PostId
    LEFT JOIN 
        PostHistory ph ON fp.PostId = ph.PostId AND ph.PostHistoryTypeId IN (4, 5, 6)
    GROUP BY 
        fp.PostId, fp.Title, fp.TotalBounty, fp.DisplayName, fp.UserLocation, fp.PostStatus
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.TotalBounty,
    pd.DisplayName,
    pd.UserLocation,
    pd.PostStatus,
    pd.CommentCount,
    pd.EditTagCount,
    pd.LastEditDate,
    CASE 
        WHEN pd.TotalBounty > 100 THEN 'High Bounty Post'
        WHEN pd.TotalBounty BETWEEN 50 AND 100 THEN 'Medium Bounty Post'
        ELSE 'Low Bounty Post'
    END AS BountyClassification,
    CASE 
        WHEN pd.LastEditDate IS NOT NULL THEN 
            CONCAT('Last edited on ', TO_CHAR(pd.LastEditDate, 'YYYY-MM-DD HH24:MI:SS'))
        ELSE 
            'Never edited'
    END AS EditStatus
FROM 
    PostDetails pd
WHERE 
    pd.CommentCount > 0
ORDER BY 
    pd.TotalBounty DESC, pd.PostId ASC
LIMIT 10;
