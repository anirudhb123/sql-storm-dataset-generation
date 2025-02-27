WITH UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        u.Reputation, 
        COUNT(DISTINCT p.Id) AS TotalPosts, 
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TagUsage AS (
    SELECT 
        t.TagName, 
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    GROUP BY 
        t.TagName
),
RecentPostHistory AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate AS LastEditDate,
        ph.UserDisplayName,
        ph.Comment,
        pt.Name AS PostType,
        p.Title,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
)
SELECT 
    pp.UserId, 
    pp.DisplayName, 
    pp.Reputation,
    tu.TagName, 
    tu.PostCount AS PostsWithTag, 
    tu.TotalViews AS TagTotalViews,
    rph.Title,
    rph.LastEditDate,
    rph.UserDisplayName AS LastEditedBy,
    rph.Comment AS LastEditComment,
    CASE 
        WHEN pp.UpVotes > pp.DownVotes THEN 'Positive Contributor'
        ELSE 'Needs Improvement' 
    END AS UserContributionClass
FROM 
    UserActivity pp
LEFT JOIN 
    TagUsage tu ON pp.TotalPosts > 0 
LEFT JOIN 
    RecentPostHistory rph ON rph.rn = 1
WHERE 
    pp.Reputation > 100
ORDER BY 
    pp.Reputation DESC, 
    tu.PostCount DESC
LIMIT 50;
