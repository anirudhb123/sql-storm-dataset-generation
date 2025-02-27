WITH TagStats AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Only questions
    GROUP BY 
        Tag
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PopularTags AS (
    SELECT 
        ts.Tag, 
        ts.PostCount,
        ROW_NUMBER() OVER (ORDER BY ts.PostCount DESC) AS PopularityRank
    FROM 
        TagStats ts
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.QuestionCount,
        ua.CommentCount,
        ua.BadgeCount,
        ua.UpVotes,
        ua.DownVotes,
        ROW_NUMBER() OVER (ORDER BY ua.UpVotes DESC) AS PopularityRank
    FROM 
        UserActivity ua
)
SELECT 
    tu.DisplayName AS UserName,
    tu.QuestionCount,
    tu.CommentCount,
    tu.BadgeCount,
    tu.UpVotes,
    tu.DownVotes,
    pt.Tag,
    pt.PostCount
FROM 
    TopUsers tu
JOIN 
    PopularTags pt ON pt.PopularityRank <= 5  -- Get top 5 popular tags
WHERE 
    tu.QuestionCount > 0  -- Only users who asked questions
ORDER BY 
    tu.UpVotes DESC, 
    pt.PostCount DESC;
