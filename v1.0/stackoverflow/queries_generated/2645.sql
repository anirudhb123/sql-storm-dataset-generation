WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount
),
RecentTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts pt ON t.Id = ANY(string_to_array(pt.Tags, '::uuid'))::int[] 
    WHERE 
        pt.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        t.TagName
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 50
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.UpVotes,
    rp.DownVotes,
    rt.TagName,
    tu.DisplayName AS TopUser,
    CASE 
        WHEN rp.UserPostRank = 1 THEN 'Most Recent'
        ELSE 'Older'
    END AS PostStat
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentTags rt ON rp.PostId = rt.PostCount
JOIN 
    TopUsers tu ON rp.ViewCount > 100
WHERE 
    rp.CreationDate >= (SELECT MIN(CreationDate) FROM Posts WHERE PostTypeId = 1)
ORDER BY 
    rp.CreationDate DESC, rp.UpVotes DESC
FETCH FIRST 100 ROWS ONLY;
