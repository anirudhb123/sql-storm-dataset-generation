WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        p.AnswerCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagList,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Tags t ON t.Id = ANY (STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')::int[])
    WHERE 
        p.PostTypeId = 1 -- Focusing on Questions only
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.Tags, p.AnswerCount, p.OwnerUserId
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        SUM(CASE WHEN pv.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN pv.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id AND p.PostTypeId = 1
    LEFT JOIN 
        Votes pv ON pv.PostId = p.Id
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.Views
)

SELECT 
    ur.UserId,
    ur.DisplayName,
    ur.Reputation,
    ur.Views,
    ur.QuestionsAsked,
    ur.TotalUpvotes,
    ur.TotalDownvotes,
    COUNT(rp.PostId) AS TotalHighRankedPosts,
    AVG(rp.Score) AS AvgPostScore,
    STRING_AGG(rp.Title, '; ') AS HighRankedPostTitles,
    STRING_AGG(rp.TagList, '; ') AS AssociatedTags
FROM 
    UserReputation ur
LEFT JOIN 
    RankedPosts rp ON rp.Rank <= 3 AND rp.OwnerUserId = ur.UserId
GROUP BY 
    ur.UserId, ur.DisplayName, ur.Reputation, ur.Views, ur.QuestionsAsked, ur.TotalUpvotes, ur.TotalDownvotes
ORDER BY 
    ur.Reputation DESC, TotalHighRankedPosts DESC;
