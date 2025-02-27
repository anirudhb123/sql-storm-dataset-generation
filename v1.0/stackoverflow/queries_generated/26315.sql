WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS WikiCount,
        SUM(CASE WHEN p.UpVotes > 0 THEN p.UpVotes ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN p.DownVotes > 0 THEN p.DownVotes ELSE 0 END) AS TotalDownVotes,
        COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2), 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        WikiCount,
        TotalUpVotes,
        TotalDownVotes,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserStats
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(DISTINCT TRIM(UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><'))), ', ') AS TagNames
    FROM 
        Posts p
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        pt.Name AS PostType,
        t.TagNames,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        PostTags t ON p.Id = t.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, pt.Name, t.TagNames
    ORDER BY 
        ViewCount DESC
)
SELECT 
    tu.DisplayName AS TopUser,
    tu.Reputation,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    tp.Title AS TopPostTitle,
    tp.ViewCount AS TopPostViews,
    tp.CommentCount AS TopPostComments,
    tp.TagNames
FROM 
    TopUsers tu
JOIN 
    TopPosts tp ON tu.UserId = (SELECT OwnerUserId FROM Posts ORDER BY ViewCount DESC LIMIT 1)
WHERE 
    tu.Rank <= 10;
