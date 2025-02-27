WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ARRAY_AGG(DISTINCT t.TagName) AS TagList,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS RevisionCount,
        MAX(ph.CreationDate) AS LastRevisionDate
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS tagName ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tagName
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),
CommentDetails AS (
    SELECT 
        c.Id AS CommentId,
        c.PostId,
        c.Score,
        c.Text,
        c.CreationDate,
        u.DisplayName AS UserDisplayName
    FROM 
        Comments c
    LEFT JOIN 
        Users u ON c.UserId = u.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalUpVotes DESC
    LIMIT 10
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Body,
    pd.TagList,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.OwnerDisplayName,
    pd.CommentCount,
    pd.RevisionCount,
    pd.LastRevisionDate,
    ARRAY_AGG(DISTINCT cd.CommentId) AS CommentIds,
    ARRAY_AGG(DISTINCT cd.Text) AS Comments,
    ARRAY_AGG(DISTINCT top.DisplayName) AS TopCommenters
FROM 
    PostDetails pd
LEFT JOIN 
    CommentDetails cd ON pd.PostId = cd.PostId
LEFT JOIN 
    TopUsers top ON cd.UserDisplayName = top.DisplayName
GROUP BY 
    pd.PostId, pd.Title, pd.Body, pd.TagList, pd.CreationDate, pd.ViewCount, pd.Score, pd.OwnerDisplayName, pd.CommentCount, pd.RevisionCount, pd.LastRevisionDate
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC;
