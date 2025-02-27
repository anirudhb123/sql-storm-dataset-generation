WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Owner,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0
), RecentEdits AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5) -- Edit Title or Edit Body
    GROUP BY 
        ph.PostId
), TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.UpVotes) AS TotalUpvotes,
        DENSE_RANK() OVER(ORDER BY SUM(u.UpVotes) DESC) AS UserRank
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(u.UpVotes) > 0
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Owner,
    rp.CreationDate,
    rp.ViewCount,
    COALESCE(re.EditCount, 0) AS EditCount,
    COALESCE(re.LastEditDate, 'No Edits') AS LastEditDate,
    tu.DisplayName AS TopUser,
    tu.TotalUpvotes
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentEdits re ON rp.PostId = re.PostId
LEFT JOIN 
    (SELECT UserId, DisplayName, TotalUpvotes FROM TopUsers WHERE UserRank <= 5) tu ON rp.OwnerUserId = tu.UserId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
