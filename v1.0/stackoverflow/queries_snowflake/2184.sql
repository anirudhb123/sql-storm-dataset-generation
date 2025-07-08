
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopTags AS (
    SELECT 
        TRIM(SPLIT_PART(Tags, '><', seq.seq)) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts,
        (SELECT SEQ4() AS seq FROM TABLE(GENERATOR(ROWCOUNT => 100))) seq
    WHERE 
        Tags IS NOT NULL AND 
        seq.seq <= ARRAY_SIZE(REGEXP_SPLIT_TO_ARRAY(Tags, '><'))
    GROUP BY 
        TRIM(SPLIT_PART(Tags, '><', seq.seq))
    ORDER BY 
        TagCount DESC
    LIMIT 5
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.TotalComments,
    us.TotalUpVotes,
    us.TotalDownVotes,
    rp.Title AS RecentPostTitle,
    rp.Score AS RecentPostScore,
    rp.ViewCount AS RecentPostViews,
    tt.TagName
FROM 
    UserStats us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId AND rp.Rank = 1
LEFT JOIN 
    TopTags tt ON us.TotalPosts > 0
WHERE 
    us.Reputation > 1000
ORDER BY 
    us.Reputation DESC, us.TotalUpVotes DESC, us.TotalPosts ASC
LIMIT 10;
