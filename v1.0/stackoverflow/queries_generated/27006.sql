WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        p.OwnerUserId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.LastActivityDate, p.OwnerUserId
),

PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
),

TopUsers AS (
    SELECT 
        u.DisplayName,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS UpVotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalViews DESC, UpVotesReceived DESC
    LIMIT 10
)

SELECT 
    rp.Rank,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.LastActivityDate,
    rp.CommentCount,
    rp.AnswerCount,
    tt.TagName,
    tu.DisplayName AS TopUser,
    tu.TotalViews,
    tu.UpVotesReceived
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularTags tt ON rp.PostId = tt.PostCount -- Example of joining with PopularTags, you might need a different join condition
JOIN 
    TopUsers tu ON rp.OwnerUserId = tu.Id
WHERE 
    rp.Rank <= 10 -- Get top 10 ranked posts
ORDER BY 
    rp.Rank;
