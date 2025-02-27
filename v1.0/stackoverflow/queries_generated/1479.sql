WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, u.DisplayName
),

RecentEdits AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5) -- Edit Title or Edit Body
    GROUP BY 
        ph.PostId
),

TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.VoteTypeId = 2) AS TotalUpVotes,
        SUM(v.VoteTypeId = 3) AS TotalDownVotes,
        RANK() OVER (ORDER BY SUM(v.VoteTypeId = 2) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.OwnerName,
    rp.CommentCount,
    re.LastEditDate,
    tu.DisplayName AS TopVoterName,
    tu.TotalUpVotes,
    tu.TotalDownVotes
FROM 
    RankedPosts rp
JOIN 
    RecentEdits re ON rp.PostId = re.PostId
LEFT JOIN 
    TopUsers tu ON tu.UserId = (
        SELECT TOP 1 UserId 
        FROM Votes v 
        WHERE v.PostId = rp.PostId 
        ORDER BY v.CreationDate DESC
    )
WHERE 
    rp.CommentCount > 5 
AND 
    rp.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY 
    rp.Score DESC, rp.CommentCount DESC;
