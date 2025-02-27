WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        PostId, Title, CreationDate, ViewCount, OwnerDisplayName, AnswerCount, UpVotes, DownVotes
    FROM 
        RankedPosts
    WHERE 
        rn <= 5
)
SELECT 
    f.OwnerDisplayName,
    COUNT(f.PostId) AS TotalPosts,
    SUM(f.ViewCount) AS TotalViews,
    AVG(f.AnswerCount * (f.UpVotes - f.DownVotes)) AS EngagementScore
FROM 
    FilteredPosts f
GROUP BY 
    f.OwnerDisplayName
ORDER BY 
    TotalViews DESC, EngagementScore DESC;
