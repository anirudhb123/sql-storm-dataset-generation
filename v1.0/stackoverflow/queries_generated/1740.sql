WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) as PostRank,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) as UpVotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) as DownVotes
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= now() - interval '1 year'
),
UserStats AS (
    SELECT 
        u.Id as UserId,
        u.DisplayName,
        COUNT(DISTINCT r.Id) as TotalPosts,
        SUM(r.Score) as TotalScore,
        SUM(r.UpVotes) as TotalUpVotes,
        SUM(r.DownVotes) as TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts r ON u.Id = r.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(p.Tags, '>')) AS TagName,
        COUNT(*) as TagCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= now() - interval '1 year'
    GROUP BY 
        TagName
),
TopUsers AS (
    SELECT
        us.UserId,
        us.DisplayName,
        us.TotalPosts,
        RANK() OVER (ORDER BY us.TotalScore DESC) as UserRank
    FROM 
        UserStats us
    WHERE 
        us.TotalPosts > 0
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalScore,
    tu.UserRank,
    COALESCE(pt.TagCount, 0) as PopularTagCount
FROM 
    TopUsers tu
LEFT JOIN 
    PopularTags pt ON pt.TagName IN (
        SELECT tag_name FROM (
            SELECT DISTINCT unnest(string_to_array(p.Tags, '>')) AS tag_name
            FROM Posts p
        ) as t
    )
WHERE 
    tu.UserRank <= 10
ORDER BY 
    tu.UserRank;
