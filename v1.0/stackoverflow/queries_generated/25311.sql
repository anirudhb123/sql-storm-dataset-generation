WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        ARRAY_LENGTH(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><'), 1) AS TagCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id
),

TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.CreationDate,
        rp.Score,
        rp.TagCount,
        rp.CommentCount,
        rp.VoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.RowNum <= 5  -- Top 5 posts per user
),

UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.AnswerCount) AS TotalAnswers,
        AVG(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - u.CreationDate))/3600) AS AverageLifetimeInHours
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
)

SELECT 
    us.DisplayName,
    us.BadgeCount,
    us.TotalScore,
    us.TotalViews,
    us.TotalAnswers,
    us.AverageLifetimeInHours,
    tp.Title AS TopPostTitle,
    tp.CreationDate AS TopPostDate,
    tp.Score AS TopPostScore,
    tp.TagCount AS TopPostTagCount,
    tp.CommentCount AS TopPostCommentCount,
    tp.VoteCount AS TopPostVoteCount
FROM 
    UserStats us
LEFT JOIN 
    TopPosts tp ON us.UserId = tp.OwnerUserId
ORDER BY 
    us.TotalScore DESC,
    us.BadgeCount DESC;
