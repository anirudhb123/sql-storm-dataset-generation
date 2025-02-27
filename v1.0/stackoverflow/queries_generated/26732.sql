WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only considering Questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'  -- Only posts from the last year
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5  -- Taking top 5 questions per tag
),
TagStatistics AS (
    SELECT 
        unnest(string_to_array(rp.Tags, '>')) AS Tag,
        COUNT(*) AS QuestionCount,
        SUM(rp.Score) AS TotalScore,
        AVG(rp.ViewCount) AS AvgViewCount
    FROM 
        TopPosts rp
    GROUP BY 
        Tag
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(v.BountyAmount) AS TotalBounties,
        SUM(b.Class) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ts.Tag,
    ts.QuestionCount,
    ts.TotalScore,
    ts.AvgViewCount,
    ua.DisplayName AS TopUser,
    ua.PostsCount,
    ua.TotalBounties,
    ua.TotalBadges
FROM 
    TagStatistics ts
JOIN 
    UserActivity ua ON ua.PostsCount = (
        SELECT 
            MAX(PostsCount) 
        FROM 
            UserActivity 
        WHERE 
            UserId IN (
                SELECT 
                    p.OwnerUserId 
                FROM 
                    Posts p 
                WHERE 
                    p.Tags LIKE '%' || ts.Tag || '%'
            )
    )
ORDER BY 
    ts.QuestionCount DESC, ts.TotalScore DESC;
