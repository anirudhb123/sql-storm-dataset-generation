WITH RankedPosts AS (
    SELECT
        p.Id as PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        u.DisplayName as OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) as RecentPostRank
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE
        p.PostTypeId = 1 -- Only considering questions
    GROUP BY
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, p.Tags, u.DisplayName
),
PostMetrics AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        rp.AnswerCount,
        CASE 
            WHEN rp.RecentPostRank = 1 THEN 'Most Recent'
            ELSE 'Older Post'
        END AS PostAgeCategory,
        STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags
    FROM
        RankedPosts rp
    LEFT JOIN
        Posts p ON rp.PostId = p.Id
    LEFT JOIN
        Tags t ON t.Id = ANY(string_to_array(substring(rp.Tags, 2, length(rp.Tags)-2), '><')::int[])
    GROUP BY
        rp.PostId, rp.Title, rp.OwnerDisplayName, rp.CreationDate, rp.ViewCount, rp.Score, rp.CommentCount, rp.AnswerCount, rp.RecentPostRank
)
SELECT 
    pm.OwnerDisplayName,
    COUNT(pm.PostId) AS TotalPosts,
    SUM(pm.ViewCount) AS TotalViews,
    SUM(pm.Score) AS TotalScore,
    SUM(pm.CommentCount) AS TotalComments,
    SUM(pm.AnswerCount) AS TotalAnswers,
    pm.PostAgeCategory,
    STRING_AGG(pm.Title, '; ') AS Titles,
    STRING_AGG(pm.AssociatedTags, '; ') AS TagsSummary
FROM 
    PostMetrics pm
GROUP BY 
    pm.OwnerDisplayName, pm.PostAgeCategory
ORDER BY 
    TotalPosts DESC, TotalScore DESC;
