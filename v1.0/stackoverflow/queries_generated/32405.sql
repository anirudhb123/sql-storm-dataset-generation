WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) >= 10
),
RecentVotes AS (
    SELECT 
        v.PostId,
        v.UserId,
        vt.Name AS VoteType,
        v.CreationDate
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        v.CreationDate >= NOW() - INTERVAL '30 days'
),
PostStatistics AS (
    SELECT
        rp.Title,
        rp.ViewCount,
        rp.AnswerCount,
        COALESCE(v.VoteCount, 0) AS VoteCount,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentVotes v ON rp.Id = v.PostId
    LEFT JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON rp.Id = c.PostId
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        rp.Title, rp.ViewCount, rp.AnswerCount, u.DisplayName, u.Reputation
),
FilteredPosts AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY TotalScore DESC, QuestionsAsked DESC) AS PostRank
    FROM 
        PostStatistics
)
SELECT 
    fp.Title,
    fp.ViewCount,
    fp.AnswerCount,
    fp.VoteCount,
    fp.DisplayName AS UserDisplayName,
    fp.Reputation,
    fp.CommentCount,
    fp.BadgeCount
FROM 
    FilteredPosts fp
WHERE 
    PostRank <= 50
ORDER BY 
    fp.TotalScore DESC,
    fp.ViewCount DESC;
