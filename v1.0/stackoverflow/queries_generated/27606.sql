WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount,
        Rank
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10 -- Get top 10 questions
),
PostTagCounts AS (
    SELECT 
        UNNEST(string_to_array(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><')) AS Tag,
        PostId
    FROM 
        TopPosts
),
TagUsage AS (
    SELECT 
        Tag,
        COUNT(PostId) AS UsageCount
    FROM 
        PostTagCounts
    GROUP BY 
        Tag
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS PostsCreated,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgesEarned
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    tp.Title,
    tp.Body,
    tp.Tags,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tu.Tag,
    tu.UsageCount,
    us.DisplayName AS UserName,
    us.PostsCreated,
    us.BadgesEarned
FROM 
    TopPosts tp
JOIN 
    PostTagCounts pt ON tp.PostId = pt.PostId
JOIN 
    TagUsage tu ON pt.Tag = tu.Tag
JOIN 
    Users us ON tp.OwnerUserId = us.Id
ORDER BY 
    tp.Score DESC, us.Reputation DESC, tu.UsageCount DESC;

