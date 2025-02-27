WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  -- Edit Title, Edit Body, Edit Tags
    GROUP BY 
        ph.PostId
),
TopUsers AS (
    SELECT 
        ur.UserId,
        RANK() OVER (ORDER BY SUM(ur.Reputation) DESC) AS UserRank
    FROM 
        UserReputation ur
    GROUP BY 
        ur.UserId
    HAVING 
        SUM(ur.BadgeCount) > 2  -- Only consider users with more than two badges
)

SELECT 
    p.Title AS Post_Title,
    pp.UserDisplayName AS Author,
    rp.CommentCount AS Comment_Total,
    ph.EditCount AS Total_Edits,
    ph.LastEditDate AS Last_Edited,
    COALESCE(RANK() OVER (PARTITION BY rp.OwnerUserId ORDER BY rp.Score DESC), 0) AS User_Post_Rank,
    COALESCE(x.UserRank, 'N/A') AS User_Rank,
    CASE 
        WHEN rp.ViewCount IS NULL THEN 'No Views' 
        ELSE CAST(rp.ViewCount AS VARCHAR) 
    END AS View_Status,
    CASE 
        WHEN rp.Score < 0 THEN 'Dissatisfactory'
        WHEN rp.Score BETWEEN 0 AND 10 THEN 'Moderate'
        ELSE 'Outstanding'
    END AS Score_Category
FROM 
    RankedPosts rp
LEFT JOIN 
    Users pp ON rp.OwnerUserId = pp.Id
LEFT JOIN 
    PostHistoryStats ph ON rp.PostId = ph.PostId
LEFT JOIN 
    TopUsers x ON pp.Id = x.UserId
WHERE 
    rp.RN = 1
ORDER BY 
    rp.Score DESC, pp.Reputation DESC;

This SQL query incorporates various advanced SQL constructs including Common Table Expressions (CTEs), window functions, left outer joins, correlated subqueries, complex case expressions, and string manipulations. The query focuses on retrieving detailed information about the most recent posts from users while incorporating statistics about edits and rankings of the users based on their contributions and reputation in the system.
