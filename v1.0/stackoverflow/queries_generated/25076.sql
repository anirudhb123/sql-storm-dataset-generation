WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- We are only interested in questions
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        AVG(COALESCE(p.Score, 0)) AS AverageScore,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.UpVotes) AS TotalUpVotes,
        SUM(p.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
LongBodyPosts AS (
    SELECT 
        PostId,
        LENGTH(Body) AS BodyLength,
        Tags
    FROM 
        Posts
    WHERE 
        LENGTH(Body) > 1000  -- Filtering long body posts
),
TagStats AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Only questions
    GROUP BY 
        Tag
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.QuestionCount,
    us.AverageScore,
    us.TotalViews,
    lb.BodyLength,
    ts.Tag AS PopularTag,
    ts.PostCount,
    rp.PostId AS RecentPostId,
    rp.Title AS RecentPostTitle,
    rp.Score AS RecentPostScore
FROM 
    UserStats us
LEFT JOIN 
    LongBodyPosts lb ON us.QuestionCount > 0  -- Joining with users who have posted questions
LEFT JOIN 
    TagStats ts ON us.QuestionCount > 0 AND ts.PostCount > 10  -- Joining popular tags with more than 10 posts
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId AND rp.RecentPostRank = 1  -- Getting recent post info
WHERE 
    us.Reputation > 100  -- Considering only users with reputation > 100
ORDER BY 
    us.Reputation DESC, us.QuestionCount DESC;
