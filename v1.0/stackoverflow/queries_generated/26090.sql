WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        COUNT(c.Id) AS CommentCount,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '>')::int[]) 
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        t.TagName
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) AS DownVoteCount,
        RANK() OVER (ORDER BY SUM(v.VoteTypeId = 2) DESC) AS Rank
    FROM 
        Users u
    JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
DetailedPostInfo AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CommentCount,
        rp.ViewCount,
        pt.TagName,
        tu.DisplayName AS TopUser,
        tu.UpVoteCount,
        tu.DownVoteCount
    FROM 
        RankedPosts rp
    JOIN 
        PopularTags pt ON pt.PostCount > 5  -- Only tags with more than 5 associated posts
    JOIN 
        TopUsers tu ON tu.UpVoteCount > 10  -- Only top users with more than 10 upvotes
)

SELECT 
    dpi.PostId,
    dpi.Title,
    dpi.Body,
    dpi.CommentCount,
    dpi.ViewCount,
    dpi.TagName,
    dpi.TopUser,
    dpi.UpVoteCount,
    dpi.DownVoteCount
FROM 
    DetailedPostInfo dpi
WHERE 
    dpi.CommentCount > 5  -- Only consider posts with more than 5 comments
ORDER BY 
    dpi.ViewCount DESC, dpi.CommentCount DESC;
