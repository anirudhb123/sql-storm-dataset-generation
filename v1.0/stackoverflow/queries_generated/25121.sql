WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        STRING_AGG(t.TagName, ', ') AS Tags,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE vt.Name = 'UpMod') AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE vt.Name = 'DownMod') AS DownVoteCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Tags t ON t.Id IN (SELECT unnest(string_to_array(p.Tags, '><'))) 
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        p.PostTypeId = 1 -- considering only questions
    GROUP BY 
        p.Id, u.Id
),
RecentActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(rp.UpVoteCount - rp.DownVoteCount) AS NetScore
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerDisplayName = u.DisplayName
    WHERE 
        rp.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        NetScore,
        RANK() OVER (ORDER BY NetScore DESC) AS Rank
    FROM 
        RecentActiveUsers
)
SELECT 
    tu.Rank,
    tu.DisplayName,
    tu.NetScore,
    STRING_AGG(DISTINCT rp.Title, '; ') AS RecentPosts
FROM 
    TopUsers tu
JOIN 
    RankedPosts rp ON tu.UserId = rp.OwnerUserId
WHERE 
    tu.Rank <= 10
GROUP BY 
    tu.Rank, tu.DisplayName, tu.NetScore
ORDER BY 
    tu.Rank;
