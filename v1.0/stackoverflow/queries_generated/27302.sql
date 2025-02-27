WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
),
TopQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        SUM(c.Id IS NOT NULL) AS CommentCount,
        SUM(p.AnswerCount) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 2 -- Count only Answers
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.BadgeCount,
    us.UpVotes,
    us.DownVotes,
    us.CommentCount,
    us.AnswerCount,
    us.TotalViews,
    tq.PostId,
    tq.Title,
    tq.Body,
    tq.CreationDate,
    tq.Score,
    tq.ViewCount,
    STRING_AGG(tq.Tags, ', ') AS Tags
FROM 
    UserStats us
JOIN 
    Posts p ON us.UserId = p.OwnerUserId
JOIN 
    TopQuestions tq ON p.Id = tq.PostId
GROUP BY 
    us.UserId, us.DisplayName, us.BadgeCount, us.UpVotes, us.DownVotes, us.CommentCount, us.AnswerCount, us.TotalViews, tq.PostId, tq.Title, tq.Body, tq.CreationDate, tq.Score, tq.ViewCount
ORDER BY 
    us.TotalViews DESC, us.BadgeCount DESC;
