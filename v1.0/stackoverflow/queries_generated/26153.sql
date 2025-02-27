WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY ARRAY(SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))) ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
        AND p.ViewCount > 100
),
UserInteractions AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT v.Id) AS VoteCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TaggedPostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        COUNT(DISTINCT ci.Id) AS InteractionCount,
        AVG(ui.VoteCount) AS AvgVoteCount,
        AVG(ui.CommentCount) AS AvgCommentCount,
        STRING_AGG(DISTINCT ui.DisplayName, ', ') AS ActiveUsers
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments ci ON rp.PostId = ci.PostId
    LEFT JOIN 
        UserInteractions ui ON ci.UserId = ui.UserId
    GROUP BY 
        rp.PostId, rp.Title, rp.Tags 
)
SELECT 
    ts.PostId,
    ts.Title,
    ts.Tags,
    ts.InteractionCount,
    ts.AvgVoteCount,
    ts.AvgCommentCount,
    ts.ActiveUsers
FROM 
    TaggedPostStats ts
WHERE 
    ts.InteractionCount > 5
ORDER BY 
    ts.AvgVoteCount DESC, ts.InteractionCount DESC;
