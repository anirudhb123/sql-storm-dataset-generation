WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        STRING_AGG(t.TagName, ', ') AS Tags,
        COUNT(v.Id) AS VoteCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.Id = ANY (STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')::int[])
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, p.PostTypeId
),
TopQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.VoteCount,
        rp.CommentCount,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 AND 
        (SELECT COUNT(*) FROM Posts pp WHERE pp.ParentId = rp.PostId) > 0 -- must have answers
),
TopUserContributions AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    WHERE 
        u.CreationDate >= NOW() - INTERVAL '2 years'
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    tq.Title AS QuestionTitle,
    tq.ViewCount,
    tq.VoteCount,
    tq.CommentCount,
    tq.Tags,
    tuc.DisplayName AS TopUser,
    tuc.PostCount,
    tuc.CommentCount AS UserCommentCount,
    tuc.BadgeCount
FROM 
    TopQuestions tq
JOIN 
    TopUserContributions tuc ON tuc.PostCount > 10 -- Only considering users with more than 10 posts
ORDER BY 
    tq.VoteCount DESC, tq.ViewCount DESC;
