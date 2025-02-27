WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreatedDate, 
        p.OwnerUserId, 
        COUNT(a.Id) AS AnswerCount, 
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days' 
        AND p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id, 
        u.DisplayName, 
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        v.CreationDate >= NOW() - INTERVAL '1 year' 
        AND v.VoteTypeId = 8 -- Bounty start votes
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalBounties DESC
    LIMIT 10
),
FilteredTags AS (
    SELECT 
        t.TagName, 
        COUNT(pt.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%' 
    JOIN 
        PostTypes pt ON pt.Id = p.PostTypeId
    WHERE 
        pt.Name IN ('Question', 'Answer') -- Only interested in these post types
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(pt.Id) > 5 -- Must appear in more than 5 posts
)
SELECT 
    rp.Title AS QuestionTitle, 
    rp.AnswerCount, 
    rp.CommentCount, 
    u.DisplayName AS BountyUser, 
    t.TagName AS PopularTag
FROM 
    RecentPosts rp
LEFT JOIN 
    TopUsers u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    FilteredTags t ON rp.Tags LIKE '%' || t.TagName || '%'
ORDER BY 
    rp.CreatedDate DESC
LIMIT 50;
