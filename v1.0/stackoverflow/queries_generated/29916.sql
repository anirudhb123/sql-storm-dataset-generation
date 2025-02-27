WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Body,
        COUNT(a.Id) AS AnswerCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes, -- Upmod
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes, -- Downmod
        RANK() OVER (ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Body
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Body,
        AnswerCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        AnswerCount > 5 AND UpVotes - DownVotes > 10 -- Filter criteria
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 10 -- Minimum posts tagged
),
UserActivity AS (
    SELECT 
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounty 
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.VoteTypeId IN (8, 9) -- Bounty Start and Close
    GROUP BY 
        u.DisplayName
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.Body,
    fp.AnswerCount,
    ts.TagName,
    ts.PostCount,
    ts.TotalViews,
    ua.DisplayName,
    ua.BadgeCount,
    ua.TotalBounty
FROM 
    FilteredPosts fp
JOIN 
    TagStatistics ts ON fp.Body LIKE '%' || ts.TagName || '%'
JOIN 
    UserActivity ua ON ua.DisplayName IN (
        SELECT DISTINCT OwnerDisplayName 
        FROM Posts 
        WHERE Id = fp.PostId
    )
ORDER BY 
    fp.CreationDate DESC, ts.TotalViews DESC;
