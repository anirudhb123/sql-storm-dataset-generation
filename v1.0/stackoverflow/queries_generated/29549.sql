WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        pt.Name AS PostType,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
        AND p.ViewCount > 1000
),

TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(CAST(p.Score AS FLOAT)) AS AvgScore
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(p.Tags, '>')::int[])
    GROUP BY 
        t.TagName
),

BadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),

UserActivity AS (
    SELECT 
        u.DisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE 
            WHEN v.VoteTypeId = 2 THEN 1 
            ELSE 0 
        END) AS UpVoteCount,
        SUM(CASE 
            WHEN v.VoteTypeId = 3 THEN 1 
            ELSE 0 
        END) AS DownVoteCount
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.DisplayName
)

SELECT 
    rp.Title,
    rp.OwnerDisplayName,
    rp.PostType,
    TagStats.TagName,
    TagStats.PostCount,
    TagStats.TotalViews,
    TagStats.AvgScore,
    ua.DisplayName AS ActiveUser,
    ua.CommentCount,
    ua.UpVoteCount,
    ua.DownVoteCount,
    bc.BadgeCount
FROM 
    RankedPosts rp
JOIN 
    TagStatistics TagStats ON rp.PostId IN (SELECT PostId FROM Posts WHERE Tags LIKE '%' || TagStats.TagName || '%')
JOIN 
    UserActivity ua ON rp.OwnerDisplayName = ua.DisplayName
JOIN 
    BadgeCounts bc ON ua.UserId = bc.UserId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, TagStats.TotalViews DESC;

