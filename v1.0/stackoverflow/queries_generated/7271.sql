WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        COALESCE(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0) AS NetVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.AnswerCount,
        rp.NetVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1 AND 
        rp.Score > 10 AND 
        rp.ViewCount > 100
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        PostCount DESC
    LIMIT 10
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.OwnerDisplayName,
    fp.AnswerCount,
    fp.NetVotes,
    tu.DisplayName AS TopUserDisplayName,
    tu.PostCount,
    tu.TotalScore
FROM 
    FilteredPosts fp
JOIN 
    TopUsers tu ON fp.OwnerUserId = tu.Id
ORDER BY 
    fp.Score DESC, fp.ViewCount DESC;
