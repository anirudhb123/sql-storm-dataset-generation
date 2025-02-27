WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounty,
        RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC, u.Reputation DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        PostCount, 
        BadgeCount, 
        TotalBounty
    FROM 
        RankedUsers
    WHERE 
        UserRank <= 10
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate,
        p.LastActivityDate,
        STRING_AGG(t.TagName, ', ') AS TagsList
    FROM 
        Posts p
    LEFT JOIN 
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tag ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag
    GROUP BY 
        p.Id
),
UserPostActivity AS (
    SELECT 
        u.DisplayName AS UserName,
        p.Title AS PostTitle,
        ps.ViewCount,
        ps.AnswerCount,
        ps.CommentCount,
        ps.CreationDate,
        ps.LastActivityDate,
        ps.TagsList
    FROM 
        TopUsers u
    JOIN 
        Posts p ON u.UserId = p.OwnerUserId
    JOIN 
        PostStats ps ON p.Id = ps.PostId
    ORDER BY 
        u.Reputation DESC, 
        ps.ViewCount DESC
)
SELECT 
    UserName,
    PostTitle,
    ViewCount,
    AnswerCount,
    CommentCount,
    CreationDate,
    LastActivityDate,
    TagsList
FROM 
    UserPostActivity
ORDER BY 
    ViewCount DESC;
